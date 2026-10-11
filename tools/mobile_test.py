from playwright.sync_api import sync_playwright
def run(p,w,h,tag):
    b=p.chromium.launch(args=['--no-sandbox']);c=b.new_context(viewport={'width':w,'height':h},has_touch=True,is_mobile=True,device_scale_factor=2)
    pg=c.new_page();errs=[];pg.on('pageerror',lambda e:errs.append(str(e)));pg.on('console',lambda m:errs.append(m.text) if m.type=='error' else 0)
    pg.goto('http://localhost:4173/?test');pg.wait_for_function('window.__g&&window.__g.isBooted');pg.wait_for_timeout(600)
    def tap(gx,gy):
        r=pg.evaluate("()=>{const r=document.querySelector('canvas').getBoundingClientRect();return [r.left,r.top,r.width,r.height]}")
        pg.touchscreen.tap(r[0]+gx*r[2]/960,r[1]+gy*r[3]/540);pg.wait_for_timeout(350)
    sc=lambda:pg.evaluate("()=>window.__g.scene.getScenes(true).map(s=>s.scene.key).join()")
    out={}
    tap(480,240);out['play->']=sc()                       # PLAY
    pg.wait_for_timeout(500);pg.screenshot(path=f'/tmp/{tag}_game.png')
    pad=pg.evaluate("()=>{const r=document.getElementById('pad').getBoundingClientRect();return [r.left,r.top,r.width,r.height]}")
    ev=lambda t,x:pg.evaluate("([t,x,y])=>document.getElementById('pad').dispatchEvent(new PointerEvent(t,{pointerId:7,clientX:x,clientY:y,bubbles:true}))",[t,x,pad[1]+pad[3]/2])
    st=lambda:pg.evaluate("()=>JSON.stringify(window.__t)")
    x0=lambda:pg.evaluate("()=>Math.round(window.__g.scene.getScene('Game').p.x)")
    a=x0();ev('pointerdown',pad[0]+pad[2]*.85);pg.wait_for_timeout(700);out['right']=(st(),x0()-a)
    ev('pointermove',pad[0]+pad[2]*.15);pg.wait_for_timeout(300);out['slide-left']=st()
    ev('pointerup',0);out['up']=st()
    pg.evaluate("()=>document.getElementById('bj').dispatchEvent(new PointerEvent('pointerdown',{pointerId:8,bubbles:true}))");out['jump']=st()
    pg.evaluate("()=>document.getElementById('bj').dispatchEvent(new PointerEvent('pointerup',{pointerId:8,bubbles:true}))");out['jump-up']=st()
    tap(36,36);out['paused']=pg.evaluate("()=>window.__g.scene.getScene('Game').paused");pg.screenshot(path=f'/tmp/{tag}_pause.png')
    tap(480,175);out['resumed']=not pg.evaluate("()=>window.__g.scene.getScene('Game').paused")
    tap(36,36);tap(480,430);out['menu']=sc()                 # MENU
    tap(480,330);out['levels']=sc();pg.screenshot(path=f'/tmp/{tag}_levels.png')
    tap(480,205);out['lvl1']=sc()                          # level 1 box
    out['errors']=errs[:3];print(tag,out);b.close()
with sync_playwright() as p:
    run(p,844,390,'land')
